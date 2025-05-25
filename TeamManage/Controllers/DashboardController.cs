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
    [Authorize(Roles = "Admin, Dev, Tester")]
    public class DashboardController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public DashboardController(ApplicationDbContext context) => _context = context;

        // ================ Lấy task trong project ================
        [HttpGet("task/project/{projectId}")]
        public async Task<IActionResult> GetDashboardTask([FromRoute] int projectId)
        {
            var project = await _context.Projects
                .FirstOrDefaultAsync(p => p.Id == projectId && !p.IsDeleted);
            if (project == null)
                return NotFound($"Không tìm thấy project có ID {projectId}.");

            var tasks = await _context.TaskItems
                .Where(t => t.Module.ProjectId == projectId && !t.IsDeleted)
                .ToListAsync();
            
            if (tasks == null || !tasks.Any())
                return NotFound($"Không tìm thấy task nào trong project có ID {projectId}.");

            var result = new GetDashboardTaskDTO
            {
                TotalTask = tasks.Count,
                TotalTaskInProgress = tasks.Count(t => t.Status == ProcessStatus.InProgress),
                TotalTaskCompleted = tasks.Count(t => t.Status == ProcessStatus.Done),
                TotalTaskNotStarted = tasks.Count(t => t.Status == ProcessStatus.None)
            };

            return Ok(new { scope = $"Task của project '{projectId}'", data = result });
        }

        [HttpGet("issue/project/{projectId}")]
        public async Task<IActionResult> GetDashboardIssue([FromRoute] int projectId)
        {
            var project = await _context.Projects
                .FirstOrDefaultAsync(p => p.Id == projectId && !p.IsDeleted);
            if (project == null)
                return NotFound($"Không tìm thấy project có ID {projectId}.");

            var issues = await _context.Issues
                .Include(i => i.TaskItem)
                    .ThenInclude(t => t.Module)
                .Where(i => i.TaskItem.Module.ProjectId == projectId && !i.IsDeleted)
                .ToListAsync();

            if (issues == null || !issues.Any())
                return NotFound($"Không tìm thấy issue nào trong project có ID {projectId}.");

            var result = new GetDashboardIssueDTO
            {
                TotalIssue = issues.Count,
                TotalIssueInProgress = issues.Count(i => i.Status == ProcessStatus.InProgress),
                TotalIssueCompleted = issues.Count(i => i.Status == ProcessStatus.Done),
                TotalIssueNotStarted = issues.Count(i => i.Status == ProcessStatus.None)
            };

            return Ok(new { scope = $"Issue của project '{projectId}'", data = result });
        }


        // ================ Lấy thống kế toàn bộ project ================
        [HttpGet("task/all")]
        public async Task<IActionResult> GetDashboardTaskAll()
        {
            var tasks = await _context.TaskItems
                .Include(t => t.Module)
                .ToListAsync();

            var result = new GetDashboardTaskDTO
            {
                TotalTask = tasks.Count,
                TotalTaskInProgress = tasks.Count(t => t.Status == ProcessStatus.InProgress),
                TotalTaskCompleted = tasks.Count(t => t.Status == ProcessStatus.Done),
                TotalTaskNotStarted = tasks.Count(t => t.Status == ProcessStatus.None)
            };

            return Ok(new { scope = "Task of all Project", data = result });
        }
        [HttpGet("issue/all")]
        public async Task<IActionResult> GetDashboardIssueAll()
        {
            var issues = await _context.Issues
                .Include(i => i.TaskItem)
                    .ThenInclude(t => t.Module)
                .ToListAsync();

            var result = new GetDashboardIssueDTO
            {
                TotalIssue = issues.Count,
                TotalIssueInProgress = issues.Count(i => i.Status == ProcessStatus.InProgress),
                TotalIssueCompleted = issues.Count(i => i.Status == ProcessStatus.Done),
                TotalIssueNotStarted = issues.Count(i => i.Status == ProcessStatus.None)
            };

            return Ok(new { scope = "Issue of all-project", data = result });
        }

        // Lấy
    }
}
