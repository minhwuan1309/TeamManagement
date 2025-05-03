using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeamManage.Data;
using TeamManage.Models;
using TeamManage.Models.DTO;

namespace TeamManage.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin,Tester,Dev")]

    public class ProjectController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ProjectController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ====================== Get Projects ======================

        [HttpGet]
        public async Task<IActionResult> GetAllProjects()
        {
            var projects = await _context.Projects
                .Include(p => p.Members)
                    .ThenInclude(m => m.User)
                .Include(p => p.Modules)
                .ToListAsync();

            var result = projects.Select(p => new ProjectDTO
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                StartDate = p.StartDate,
                IsDeleted = p.IsDeleted,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt,
                Members = p.Members
                    .Where(m => m.User != null)
                    .Select(m => new MemberDTO
                    {
                        FullName = m.User.FullName,
                        UserId = m.UserId,
                        RoleInProject = m.RoleInProject,
                    })
                    .ToList(),

                Modules = p.Modules
                    .Where(m => !m.IsDeleted)
                    .Select(m => new ModuleDTO
                    {
                        Id = m.Id,
                        Name =m.Name,
                        Status =m.Status
                    })
                    .ToList()
            });

            return Ok(result);
        }


        [HttpGet("{id}")]
        public async Task<IActionResult> GetProjectById(int id)
        {
            var project = await _context.Projects
                .Include(p => p.Members)
                .ThenInclude(m => m.User)
                .Include(p => p.Modules)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (project == null)
                return NotFound("Không tìm thấy project");

            var result = new ProjectDTO
            {
                Id = project.Id,
                Name = project.Name,
                Description = project.Description,
                StartDate = project.StartDate,
                IsDeleted = project.IsDeleted,
                CreatedAt = project.CreatedAt,
                UpdatedAt = project.UpdatedAt,
                Members = project.Members
                    .Where(m => m.User != null)
                    .Select(m => new MemberDTO
                    {
                        FullName = m.User.FullName,
                        UserId = m.UserId,
                        RoleInProject = m.RoleInProject,
                        Avatar = m.User.Avatar
                    })
                    .ToList(),
                Modules = project.Modules
                    .Where(m => !m.IsDeleted)
                    .Select(m => new ModuleDTO
                    {
                        Id = m.Id,
                        Name =m.Name,
                        Status =m.Status,
                    })
                    .ToList()
            };

            return Ok(result);
        }

        // ====================== Create Project ======================

        [HttpPost("create")]
        public async Task<IActionResult> CreateProject([FromBody] ProjectDTO projectDTO)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
                return Unauthorized("Bạn cần đăng nhập để tạo project");

            var members = new List<ProjectMember>();

            members.Add(new ProjectMember
            {
                UserId = userId,
                RoleInProject = UserRole.Admin,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            });

            if (projectDTO.Members != null)
            {
                foreach (var m in projectDTO.Members)
                {
                    if (m.UserId != userId)
                    {
                        members.Add(new ProjectMember
                        {
                            UserId = m.UserId,
                            RoleInProject = m.RoleInProject,
                            CreatedAt = DateTime.Now,
                            UpdatedAt = DateTime.Now
                        });
                    }
                }
            }

            var newProject = new Project
            {
                Name = projectDTO.Name,
                Description = projectDTO.Description,
                StartDate = projectDTO.StartDate,
                IsDeleted = false,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
                Members = members
            };

            _context.Projects.Add(newProject);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Tạo project thành công",
                project = newProject,
                memberCount = members.Count,
            }
            );
        }

        // ====================== Update Project ======================

        [Authorize]
        [HttpPut("update/{id}")]
        public async Task<IActionResult> UpdateProject(int id, [FromBody] ProjectDTO projectDTO)
        {
            var project = await _context.Projects.FindAsync(id);
            if (project == null || project.IsDeleted)
                return NotFound("Không tìm thấy dự án");

            // Cập nhật thông tin dự án
            if (!string.IsNullOrWhiteSpace(projectDTO.Name))
                project.Name = projectDTO.Name;
            if (!string.IsNullOrWhiteSpace(projectDTO.Description))
                project.Description = projectDTO.Description;
            if (projectDTO.StartDate != null)
                project.StartDate = projectDTO.StartDate;

            project.UpdatedAt = DateTime.Now;

            // Lấy danh sách thành viên hiện tại của dự án
            var existingMembers = await _context.ProjectMembers
                .Where(m => m.ProjectId == id && !m.IsDeleted)
                .ToListAsync();

            // Xử lý thêm hoặc cập nhật thành viên
            if (projectDTO.Members != null)
            {
                foreach (var member in projectDTO.Members)
                {
                    var existingMember = existingMembers.FirstOrDefault(m => m.UserId == member.UserId);
                    if (existingMember == null)
                    {
                        // Thêm thành viên mới
                        var newMember = new ProjectMember
                        {
                            UserId = member.UserId,
                            ProjectId = id,
                            RoleInProject = member.RoleInProject,
                            CreatedAt = DateTime.Now,
                            UpdatedAt = DateTime.Now
                        };
                        _context.ProjectMembers.Add(newMember);
                    }
                    else
                    {
                        // Cập nhật vai trò của thành viên hiện tại
                        existingMember.RoleInProject = member.RoleInProject;
                        existingMember.UpdatedAt = DateTime.Now;
                        _context.ProjectMembers.Update(existingMember);
                    }
                }

                var memberIdsToKeep = projectDTO.Members.Select(m => m.UserId).ToList();
                var membersToRemove = existingMembers
                    .Where(m => !memberIdsToKeep.Contains(m.UserId))
                    .ToList();

                _context.ProjectMembers.RemoveRange(membersToRemove);

            }

            _context.Projects.Update(project);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật dự án thành công",
                project
            });
        }

        // ====================== Delete Project (Soft Delete) ======================

        [HttpDelete("delete/{id}")]
        public async Task<IActionResult> DeleteProject(int id)
        {
            var project = await _context.Projects.FirstOrDefaultAsync(p => p.Id == id);
            if (project == null)
                return NotFound("Không tìm thấy dự án");

            project.IsDeleted = !project.IsDeleted;
            project.UpdatedAt = DateTime.Now;

            _context.Projects.Update(project);
            await _context.SaveChangesAsync();

            return Ok(project.IsDeleted
                    ? "Dự án đã được xoá mềm (ẩn khỏi danh sách)."
                    : "Dự án đã được khôi phục."
            );
        }
        [HttpDelete("hard-delete/{id}")]
        public async Task<IActionResult> HardDeleteProject(int id)
        {
            var project = await _context.Projects.FirstOrDefaultAsync(p => p.Id == id);
            if (project == null)
                return NotFound("Không tìm thấy dự án");

            _context.Projects.Remove(project);
            await _context.SaveChangesAsync();

            return Ok("Dự án đã được xóa.");
        }
    }
}
