using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.UI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using TeamManage.Data;
using TeamManage.Models;
using TeamManage.Models.DTO;
using TeamManage.Services.Email;

namespace TeamManage.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _config;
        private readonly IEmailSender _emailSender;

        public AuthController(
            UserManager<ApplicationUser> userManager,
            IConfiguration config,
            IEmailSender emailSender)
        {
            _userManager = userManager;
            _config = config;
            _emailSender = emailSender;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDTO loginDTO)
        {
            var user = await _userManager.FindByEmailAsync(loginDTO.Email);
            if (user == null || user.IsDeleted || !user.IsActive)
                return Unauthorized("Email không tồn tại hoặc tài khoản bị khoá.");

            if (!await _userManager.CheckPasswordAsync(user, loginDTO.Password))
                return Unauthorized("Sai mật khẩu.");

            var roles = await _userManager.GetRolesAsync(user);
            var authClaims = new List<Claim>
            {

                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.FullName ?? ""),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            foreach (var role in roles)
                authClaims.Add(new Claim(ClaimTypes.Role, role));

            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                expires: DateTime.Now.AddDays(7),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                token = new JwtSecurityTokenHandler().WriteToken(token),
                expiration = token.ValidTo,
                role = (int)user.Role,
                user= user
            });
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByIdAsync(userId);
            return Ok(new {user.Id, user.FullName, user.Email, user.Phone, user.Role, user.Avatar, user.IsActive, user.IsDeleted});
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDTO registerDTO)
        {
            var existingUser = await _userManager.FindByEmailAsync(registerDTO.Email);
            if (existingUser != null)
                return BadRequest("Email đã tồn tại.");

            var code = new Random().Next(100000, 999999).ToString();
            var user = new ApplicationUser
            {
                Id = Guid.NewGuid().ToString(),
                FullName = registerDTO.FullName,
                Email = registerDTO.Email,
                UserName = registerDTO.Email.Split('@')[0],
                Phone = registerDTO.Phone,
                Role = UserRole.Viewer,
                IsActive = true,
                IsDeleted = false,
                VerificationCode = code,
                VerificationExpiry = DateTime.UtcNow.AddMinutes(10),
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            var result = await _userManager.CreateAsync(user, registerDTO.Password);
            if (!result.Succeeded)
                return BadRequest(result.Errors);

            await _emailSender.SendEmailAsync(user.Email, "Xác thực tài khoản", $"Mã xác thực: {code}");
            return Ok(new { message = "Đăng ký tuyển dụng thành công, hãy kiểm tra email!" });
            
        }

        [HttpPost("verify-email")]
        public async Task<IActionResult> VerifyEmail([FromBody] VerifyDTO verifyDTO)
        {
            var user = await _userManager.FindByEmailAsync(verifyDTO.Email);
            if(user == null || user.IsDeleted || user.IsVerified)
                return BadRequest("Tài khoản không hợp lệ.");
            
            if(user.VerificationCode != verifyDTO.Code || user.VerificationExpiry < DateTime.UtcNow)
                return BadRequest("Mã xác thực khôn hợp lệ.");

            user.IsVerified = true;
            user.VerificationCode = null;
            user.VerificationExpiry = null;

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded
                ? Ok("Xác thức tài khoản thành công")
                : BadRequest(result.Errors);
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDTO dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null || user.IsDeleted)
                return NotFound("Không tìm thấy người dùng.");

            var code = new Random().Next(100000, 999999).ToString();
            user.VerificationCode = code;
            user.VerificationExpiry = DateTime.UtcNow.AddMinutes(10);

            await _userManager.UpdateAsync(user);
            await _emailSender.SendEmailAsync(user.Email, "Khôi phục mật khẩu", $"Mã xác thực đặt lại mật khẩu: {code}");
            return Ok("Đã gửi mã xác thực đến email: " + user.Email);
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDTO dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null || user.IsDeleted)
                return NotFound("Không tìm thấy người dùng.");

            if (user.VerificationCode != dto.Code || user.VerificationExpiry < DateTime.UtcNow)
                return BadRequest("Mã xác thực không hợp lệ.");
            
            user.PasswordHash = _userManager.PasswordHasher.HashPassword(user, dto.NewPassword);
            user.VerificationCode = null;
            user.VerificationExpiry = null;

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded
                ? Ok("Đặt lại mật khẩu thành công.")
                : BadRequest(result.Errors);
        }
    }
}

public class VerifyDTO
{
    public string? Email { get; set; }
    public string? Code { get; set; }
}

public class ForgotPasswordDTO
{
    public string? Email { get; set; }
}

public class ResetPasswordDTO
{
    public string? Email { get; set; }
    public string? Code { get; set; }
    public string? NewPassword { get; set; }
}
