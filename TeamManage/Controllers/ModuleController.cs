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
                .Where(m => m.ProjectId == projectId)
                .Select(m => new SimpleModuleDTO
                {
                    Id = m.Id,
                    Name = m.Name,
                    Code = m.Code,
                    Status = m.Status,
                    MemberCount = m.ModuleMembers.Count(mb => !mb.IsDeleted),
                    IsDeleted = m.IsDeleted
                })
                .ToListAsync();

            return Ok(modules);
        }

        [HttpGet("tree")]
        public async Task<IActionResult> GetModuleTree([FromQuery] int projectId)
        {
            var modules = await _context.Modules
                .Where(m => m.ProjectId == projectId && !m.IsDeleted)
                .Select(m => new ModuleTreeDTO
                {
                    Id = m.Id,
                    Name = m.Name,
                    Code = m.Code,
                    Status = m.Status,
                    MemberCount = m.ModuleMembers.Count(mb => !mb.IsDeleted),
                    IsDeleted = m.IsDeleted,
                    ParentModuleId = m.ParentModuleId,
                    ProjectId = m.ProjectId
                })
                .ToListAsync();

            var tree = BuildTree(modules, null);
            return Ok(tree);
        }
        
        private List<ModuleTreeDTO> BuildTree(List<ModuleTreeDTO> all, int? parentId)
        {
            return all
                .Where(m => m.ParentModuleId == parentId)
                .Select(m =>
                {
                    m.Children = BuildTree(all, m.Id);
                    return m;
                })
                .ToList();
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
                    .FirstOrDefaultAsync(x => x.Id == id);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            var result = new ModuleDTO
            {
                Id = module.Id,
                ProjectId = module.ProjectId,
                Name = module.Name,
                Status = module.Status,
                Code = module.Code,
                ParentModuleId = module.ParentModuleId,
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
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var module = new Module
            {
                Name = moduleDTO.Name,
                ProjectId = moduleDTO.ProjectId,
                Status = ProcessStatus.None,
                IsDeleted = false,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
                Code = "pending",
                ParentModuleId = moduleDTO.ParentModuleId,
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

            if (moduleDTO.ParentModuleId != null)
            {
                module.ParentModuleId = moduleDTO.ParentModuleId;
            }
            module.Code = await GenerateModuleCode(moduleDTO.ParentModuleId, module.Id);

            _context.Modules.Update(module);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo module thành công", module });
        }

        // Tạo mã module dựa trên ParentModuleId "1.0.0; 1.1.0; 1.2.0"
        private async Task<string> GenerateModuleCode(int? parentModuleId, int currentModuleId = 0)
        {
            // Nếu là module gốc
            if (parentModuleId == null)
            {
                return $"{currentModuleId}.0.0";
            }

            // Lấy module cha
            var parent = await _context.Modules
                .FirstOrDefaultAsync(m => m.Id == parentModuleId && !m.IsDeleted);

            if (parent == null || string.IsNullOrWhiteSpace(parent.Code))
            {
                return $"{currentModuleId}.0.0"; // fallback
            }

            var parts = parent.Code.Split('.');
            if (parts.Length != 3)
            {
                return $"{currentModuleId}.0.0"; // fallback
            }

            var rootId = parts[0];              // ID của module gốc
            var parentLevel = int.Parse(parts[1]);  // phần giữa
            var parentSuffix = int.Parse(parts[2]); // phần cuối

            // Đếm số lượng con hiện tại
            var siblingCount = await _context.Modules
                .CountAsync(m => m.ParentModuleId == parentModuleId && !m.IsDeleted);

            var childIndex = siblingCount + 1;

            // Nếu cha là root (x.0.0) thì dùng dạng x.1.0, x.2.0
            if (parentLevel == 0 && parentSuffix == 0)
            {
                return $"{rootId}.{childIndex}.0";
            }

            // Nếu cha là cấp con (x.y.0), sinh dạng x.y.1, x.y.2,...
            return $"{rootId}.{parentLevel}.{childIndex}";
        }



        // Build Module Tree
        private List<ModuleDTO> BuildModuleTree(List<Module> modules, int? parentId)
        {
            return modules
                .Where(m => m.ParentModuleId == parentId)
                .Select(m => new ModuleDTO
                {
                    Id = m.Id,
                    ProjectId = m.ProjectId,
                    Code = m.Code,
                    Name = m.Name,
                    ParentModuleId = m.ParentModuleId,
                    Status = m.Status,
                    IsDeleted = m.IsDeleted,
                    CreatedAt = m.CreatedAt,
                    UpdatedAt = m.UpdatedAt,
                    Children = BuildModuleTree(modules, m.Id)
                })
                .ToList();
        }


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

        [HttpDelete("hard-delete/{id}")]
        public async Task<IActionResult> HardDeleteModule(int id)
        {
            var module = await _context.Modules.FirstOrDefaultAsync(x => x.Id == id);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            _context.Modules.Remove(module);
            await _context.SaveChangesAsync();

            return Ok("Module đã được xóa.");
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

        // Cập nhật code phân cấp module
        [HttpPut("rebuild-codes")]
        public async Task<IActionResult> RebuildAllModuleCodes()
        {
            var modules = await _context.Modules
                .ToListAsync();

            foreach (var module in modules)
            {
                module.Code = await GenerateModuleCode(module.ParentModuleId, module.Id);
            }

            _context.Modules.UpdateRange(modules);
            await _context.SaveChangesAsync();

            return Ok("Đã cập nhật lại Code cho tất cả module.");
        }
    }
}