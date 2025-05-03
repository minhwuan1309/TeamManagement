using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeamManage.Data;
using TeamManage.Models;
using TeamManage.Models.DTO;

namespace TeamManage.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin,Dev,Tester")]
    public class ModuleController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ModuleController(ApplicationDbContext context) => _context = context;

        // ====================== Get Modules ======================

        [HttpGet]
        public async Task<IActionResult> GetModulesByProject([FromQuery] int projectId)
        {
            var modules = await _context.Modules
                .Where(m => m.ProjectId == projectId && !m.IsDeleted)
                .Select(m => new SimpleModuleDTO
                {
                    Id = m.Id,
                    Name = m.Name,
                    Status = m.Status,
                    MemberCount = m.ModuleMembers.Count(mb => !mb.IsDeleted)
                })
                .ToListAsync();

            return Ok(modules);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetModule(int id)
        {
            var module = await _context.Modules
                    .Include(m => m.Project)
                    .Include(x => x.ModuleMembers)
                        .ThenInclude(mb => mb.User)
                    .Include(t => t.Tasks)
                        .ThenInclude(t => t.AssignedUser)
                    .FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            var result = new ModuleDTO
            {
                Id = module.Id,
                ProjectId = module.ProjectId,
                Name = module.Name,
                Status = module.Status,
                // Chỉ sử dụng Members để chứa thông tin đầy đủ về thành viên
                Members = module.ModuleMembers
                            .Where(mb => !mb.IsDeleted && mb.User != null)
                            .Select(mb => new MemberDTO
                            {
                                UserId = mb.UserId,
                                FullName = mb.User.FullName,
                                Avatar = mb.User.Avatar,
                                RoleInProject = mb.User.Role, 
                            })
                            .ToList(),
                Tasks = module.Tasks
                            .Where(t => !t.IsDeleted)
                            .Select(t => new GetModuleWithTaskDTO
                            {
                                Id = t.Id,
                                Title = t.Title,
                                Status = t.Status,
                                StartDate = t.StartDate,
                                EndDate = t.EndDate,
                                AssignedUserId = t.AssignedUserId,
                                AssignedUserName = t.AssignedUser?.FullName
                            })
                            .ToList(),
                        
                IsDeleted = module.IsDeleted,
                CreatedAt = module.CreatedAt,
                UpdatedAt = module.UpdatedAt
            };
            return Ok(result);
        }

        // ====================== Create Modules ======================

        [HttpPost("create")]
        public async Task<IActionResult> CreateModule([FromBody] ModuleDTO moduleDTO)
        {
            var module = new Module
            {
                Name = moduleDTO.Name,
                ProjectId = moduleDTO.ProjectId,
                Status = moduleDTO.Status,
                IsDeleted = false,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
                ModuleMembers = moduleDTO.Members != null ?
                    moduleDTO.Members.Select(member => new ModuleMember
                    {
                        UserId = member.UserId,
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    }).ToList() : new List<ModuleMember>()
            };

            _context.Modules.Add(module);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo module thành công", module });
        }

        // ====================== Update Module ======================

        [HttpPut("update/{id}")]
        public async Task<IActionResult> UpdateModule(int id, [FromBody] ModuleDTO moduleDTO)
        {
            var module = await _context.Modules
                .Include(m => m.ModuleMembers)
                .FirstOrDefaultAsync(m => m.Id == id && !m.IsDeleted);

            if (module == null)
                return NotFound("Không tìm thấy module.");

            // Cập nhật thông tin cơ bản
            module.Name = moduleDTO.Name;
            module.Status = moduleDTO.Status;
            module.UpdatedAt = DateTime.Now;

            // Lấy danh sách thành viên được gửi lên
            var incomingIds = moduleDTO.Members?.Select(m => m.UserId).Distinct().ToList() ?? new List<string>();

            // Xóa các thành viên không còn trong danh sách
            var toRemove = module.ModuleMembers
                .Where(m => !incomingIds.Contains(m.UserId))
                .ToList();

            foreach (var member in toRemove)
            {
                module.ModuleMembers.Remove(member);
            }

            // Thêm các thành viên mới chưa có trong danh sách hiện tại
            foreach (var userId in incomingIds)
            {
                if (!module.ModuleMembers.Any(m => m.UserId == userId))
                {
                    module.ModuleMembers.Add(new ModuleMember
                    {
                        UserId = userId,
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now,
                    });
                }
            }

            _context.Modules.Update(module);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật module thành công", module });
        }


        // ====================== Delete Modules ======================

        [HttpDelete("delete/{id}")]
        public async Task<IActionResult> DeleteModule(int id)
        {
            var module = await _context.Modules.FirstOrDefaultAsync(x => x.Id == id);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            module.IsDeleted = !module.IsDeleted;
            module.UpdatedAt = DateTime.Now;

            _context.Modules.Update(module);
            await _context.SaveChangesAsync();

            return Ok(module.IsDeleted
                ? "Đã xóa module."
                : "Đã khôi phục module.");
        }

        // ====================== Update Modules Status ======================

        [HttpPut("update-status/{id}")]
        public async Task<IActionResult> UpdateModuleStatus(int id, [FromQuery] ProcessStatus status)
        {
            var module = await _context.Modules.FirstOrDefaultAsync(m => m.Id == id && !m.IsDeleted);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            module.Status = status;
            module.UpdatedAt = DateTime.Now;

            _context.Modules.Update(module);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = $"Cập nhật trạng thái module -> {status}",
                moduleId = module.Id,
                newStatus = module.Status.ToString()
            });
        }

        // ====================== Get Module's Members ======================

        [HttpGet("members/{moduleId}")]
        public async Task<IActionResult> GetModuleMembers(int moduleId)
        {
            var members = await _context.ModuleMembers
                .Where(m => m.ModuleId == moduleId && !m.IsDeleted)
                .Include(m => m.User)
                .Select(m => new MemberDTO
                {
                    UserId = m.UserId,
                    FullName = m.User.FullName,
                    Avatar = m.User.Avatar,
                    RoleInProject = m.User.Role
                })
                .ToListAsync();

            if (!members.Any())
                return NotFound("Không tìm thấy thành viên nào trong module.");

            return Ok(members);
        }
    }
}