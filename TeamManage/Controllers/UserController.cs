using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using TeamManage.Data;
using TeamManage.Models;
using TeamManage.Models.DTO;
using TeamManage.Services.CloudinaryConfig;

namespace TeamManage.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin, Dev, Tester")]
    public class UserController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _user;
        public UserController(UserManager<ApplicationUser> user) => _user = user;

        [Authorize(Roles = "Admin")]
        [HttpGet]
        public IActionResult GetAllUser()
        {
            var users = _user.Users
                .Select(u => new
                {
                    u.Id,
                    u.FullName,
                    u.Email,
                    u.Phone,
                    Role = (int)u.Role,
                    u.Avatar,
                    u.IsActive,
                    u.IsDeleted
                });
            return Ok(users);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("{id}")]
        public IActionResult GetUserById(string id)
        {
            var user = _user.Users
                .Where(u => u.Id == id)
                .Select(u => new
                {
                    u.Id,
                    u.FullName,
                    u.Email,
                    u.Phone,
                    Role = (int)u.Role,
                    u.Avatar,
                    u.IsActive,
                    u.IsDeleted
                }).FirstOrDefault();

            if (user == null)
                return NotFound("Người dùng không tồn tại hoặc đã bị xóa.");

            return Ok(user);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("create")]
        public async Task<IActionResult> CreateUser([FromBody] UserDTO userDTO)
        {
            if(string.IsNullOrWhiteSpace(userDTO.Password))
                return BadRequest("Mật khẩu là bắt buộc");

            var user = new ApplicationUser
            {
                Id = Guid.NewGuid().ToString(),
                FullName = userDTO.FullName,
                Email = userDTO.Email,
                UserName = userDTO.Email.Split('@')[0],
                Phone = userDTO.Phone,
                PasswordHash = new PasswordHasher<ApplicationUser>().HashPassword(null, userDTO.Password),
                Avatar = userDTO.Avatar,
                Role = userDTO.Role,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            var result = await _user.CreateAsync(user, userDTO.Password);
            if(!result.Succeeded)
            {
                return BadRequest(result.Errors);
            }

            await _user.AddToRoleAsync(user, userDTO.Role.ToString());
            return Ok(new { message = "Tạo tài khoản thành công", user });
        }

        [HttpPut("update/{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] UserDTO userDTO)
        {
            var user = await _user.FindByIdAsync(id);
            if(user == null || user.IsDeleted)
                return NotFound("Người dùng không tồn tại hoặc đã bị xóa.");

            if (!string.IsNullOrWhiteSpace(userDTO.FullName))
                user.FullName = userDTO.FullName;
            if (!string.IsNullOrWhiteSpace(userDTO.Phone))
                user.Phone = userDTO.Phone;
            if (!string.IsNullOrWhiteSpace(userDTO.Avatar))
                user.Avatar = userDTO.Avatar;
            if (userDTO.Role != null)
                user.Role = userDTO.Role;

            user.UpdatedAt = DateTime.Now;

            var result = await _user.UpdateAsync(user);
            if(!result.Succeeded)
            {
                return BadRequest(result.Errors);
            }

            return Ok(new { message = "Cập nhật tài khoản thành công", result });
        }

        [Authorize(Roles = "Admin")]
        [HttpPut("toggle-block/{id}")]
        public async Task<IActionResult> ToggleBlockUser(string id)
        {
            var user = await _user.FindByIdAsync(id);
            if(user == null)
                return NotFound("Không tìm thấy người dùng.");
            
            user.IsActive = !user.IsActive;
            user.UpdatedAt = DateTime.Now;

            var result = await _user.UpdateAsync(user);
            return result.Succeeded
                ? Ok(user.IsActive ? "Đã mở khóa tài khoản" : "Đã khóa tài khoản")
                : BadRequest(result.Errors);
        }

        [Authorize(Roles = "Admin")]
        [HttpDelete("delete/{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _user.FindByIdAsync(id);
            if (user == null)
                return NotFound("Không tìm thấy người dùng.");

            user.IsDeleted = !user.IsDeleted;
            user.UpdatedAt = DateTime.Now;

            var result = await _user.UpdateAsync(user);

            return result.Succeeded
                ? Ok(user.IsDeleted
                    ? "Đã ẩn tài khoản người dùng."
                    : "Đã khôi phục tài khoản người dùng.")
                : BadRequest(result.Errors);
        }

        [Authorize(Roles = "Admin")]
        [HttpDelete("hard-delete/{id}")]
        public async Task<IActionResult> HardDeleteUser(string id)
        {
            var user = await _user.FindByIdAsync(id);
            if (user == null)
                return NotFound("Không tìm thấy người dùng.");

            var result = await _user.DeleteAsync(user);
            return result.Succeeded
                ? Ok("Đã xóa tài khoản người dùng.")
                : BadRequest(result.Errors);
        }

        [Authorize]
        [HttpPut("update-profile")]
        public async Task<IActionResult> UpdateOwnProfile([FromForm] UpdateProfileDTO userDTO, IFormFile? file, [FromServices] CloudinaryService cloudinary)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _user.FindByIdAsync(userId);
            if (user == null)
                return NotFound("Không tìm thấy người dùng.");

            if (!string.IsNullOrWhiteSpace(userDTO.Phone))
            {
                var duplicatePhone = _user.Users.Any(u => u.Phone == userDTO.Phone && u.Id != user.Id);
                if (duplicatePhone)
                    return BadRequest("Số điện thoại đã được sử dụng!");
                user.Phone = userDTO.Phone;
            }

            if (!string.IsNullOrWhiteSpace(userDTO.FullName))
                user.FullName = userDTO.FullName;

            if(file != null && file.Length > 0)
            {
                var avatarUrl = await cloudinary.UploadImageAsync(file);
                if(avatarUrl == null)
                    return BadRequest("Tải hình ảnh thất bại.");

                user.Avatar = avatarUrl;
            }

            user.UpdatedAt = DateTime.Now;
            var result = await _user.UpdateAsync(user);

            if(!result.Succeeded)
                return BadRequest(result.Errors);

            return Ok(new { message = "Cập nhật thông tin thành công", result });
        }

        [Authorize(Roles = "Admin")]
        [HttpPut("update-role/{id}")]
        public async Task<IActionResult> UpdateRole(string id, [FromBody] UpdateRoleDTO dto)
        {
            var user = await _user.FindByIdAsync(id);
            if(user == null)
                return NotFound("Không tìm thấy người dùng.");

            //Xoá role cũ
            var currentRole = await _user.GetRolesAsync(user);
            if(currentRole.Any())
                await _user.RemoveFromRoleAsync(user, currentRole.First());

            user.Role = dto.Role;
            user.UpdatedAt = DateTime.Now;
            var result = await _user.UpdateAsync(user);

            await _user.AddToRoleAsync(user, dto.Role.ToString());
            return result.Succeeded
                ? Ok("Cập nhật Role thành công")
                : BadRequest(result.Errors);
        }
    }
}

public class UpdateProfileDTO
{
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? Avatar { get; set; }
}
public class UpdateRoleDTO
{
    public UserRole Role { get; set; }
}
