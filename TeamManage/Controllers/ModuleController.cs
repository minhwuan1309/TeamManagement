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
                .Include(m => m.Project)
                .Include(m=> m.ModuleMembers)
                    .ThenInclude(m => m.User)
                .Where(m => m.ProjectId == projectId && !m.IsDeleted)
                .ToListAsync();

            var result = modules.Select(m => new ModuleDTO
            {
                Id = m.Id,
                ProjectId = m.ProjectId,
                Name = m.Name,
                Status = m.Status,
                MemberIds = m.ModuleMembers
                            .Where(mb => !mb.IsDeleted)
                            .Select(mb => mb.UserId)
                            .ToList(),
                MemberNames = m.ModuleMembers
                            .Where(mb => !mb.IsDeleted && mb.User != null)
                            .Select(mb => mb.User.FullName)
                            .ToList(),
                IsDeleted = m.IsDeleted,
                CreatedAt = m.CreatedAt,
                UpdatedAt = m.UpdatedAt
            });

            return Ok(modules);
        }


        [HttpGet("{id}")]
        public async Task<IActionResult> GetModule(int id)
        {
            var module = await _context.Modules
                    .Include(m => m.Project)
                    .Include(x => x.ModuleMembers)
                        .ThenInclude(mb => mb.User)
                    .FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            var result = new ModuleDTO
            {
                Id = module.Id,
                ProjectId = module.ProjectId,
                Name = module.Name,
                Status = module.Status,
                MemberIds = module.ModuleMembers
                            .Where(mb => !mb.IsDeleted)
                            .Select(mb => mb.UserId)
                            .ToList(),
                MemberNames = module.ModuleMembers
                            .Where(mb => !mb.IsDeleted && mb.User != null)
                            .Select(mb => mb.User.FullName)
                            .ToList(),
                IsDeleted = module.IsDeleted,
                CreatedAt = module.CreatedAt,
                UpdatedAt = module.UpdatedAt
            };
            return Ok(module);
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
                ModuleMembers = moduleDTO.MemberIds.Select(userId => new ModuleMember
                {
                    UserId = userId,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                }).ToList()
            };

            _context.Modules.Add(module);
            await _context.SaveChangesAsync();

            return Ok(new {message ="Tạo module thành công", module});
            
        }

        // ====================== Update Module ======================

        [HttpPut("update/{id}")]
        public async Task<IActionResult> UpdateModule(int id, [FromBody] ModuleDTO moduleDTO)
        {
            var module = await _context.Modules
                    .Include(m => m.Project)
                    .FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            if (!string.IsNullOrWhiteSpace(moduleDTO.Name))
                module.Name = moduleDTO.Name;
            if (Enum.IsDefined(typeof(ProcessStatus), moduleDTO.Status))
                module.Status = moduleDTO.Status;
            
            module.UpdatedAt = DateTime.Now;

            if (moduleDTO.MemberIds != null)
            {
                module.ModuleMembers = moduleDTO.MemberIds.Select(userId => new ModuleMember
                {
                    UserId = userId,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                }).ToList();
            }

            _context.Modules.Update(module);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật module thành công",
                module
            });
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
                .Select(m => new
                {
                    UserId = m.UserId,
                    FullName = m.User.FullName
                })
                .ToListAsync();

            if(!members.Any())
                return NotFound("Không tìm thấy thành viên nào trong module.");
        
            return Ok(members);
        }
    }
}
