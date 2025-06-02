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


        //Function
        private List<object> BuildTrend<T>(IEnumerable<T> items, Func<T, DateTime> getDate, Func<T, ProcessStatus> getStatus)
        {
            return items
                .GroupBy(getDate)
                .OrderBy(g => g.Key)
                .Select(g => new
                {
                    date = g.Key.ToString("yyyy-MM-dd"),
                    NotStarted = g.Count(i => getStatus(i) == ProcessStatus.None),
                    InProgress = g.Count(i => getStatus(i) == ProcessStatus.InProgress),
                    Completed = g.Count(i => getStatus(i) == ProcessStatus.Done)
                })
                .Cast<object>()
                .ToList();
        }
 
        
        // Lấy theo timeline
        [HttpGet("issue/trend")]
        public async Task<IActionResult> GetIssueTrend([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var query = _context.Issues
                .Where(i => !i.IsDeleted && i.CreatedAt != null);

            if (startDate.HasValue)
                query = query.Where(i => i.CreatedAt >= startDate.Value);

            if (endDate.HasValue)
            {
                var nextDay = endDate.Value.Date.AddDays(1); 
                query = query.Where(i => i.CreatedAt < nextDay);
            }

            var issues = await query.ToListAsync();

            var trend = BuildTrend<Issue>(
                issues,
                getDate: i => i.CreatedAt,
                getStatus: i => i.Status
            );
            return Ok(trend);
        }
        
        [HttpGet("task/trend")]
        public async Task<IActionResult> GetTaskTrend([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var query = _context.TaskItems
                .Where(t => !t.IsDeleted && t.StartDate != null && t.EndDate != null);

            if (startDate.HasValue)
                query = query.Where(t => t.EndDate >= startDate.Value);

            if (endDate.HasValue)
                query = query.Where(t => t.StartDate <= endDate.Value);

            var tasks = await query.ToListAsync();

            var trend = BuildTrend<TaskItem>(
                tasks,
                getDate: t => t.StartDate!.Value,
                getStatus: t => t.Status
            );

            return Ok(trend);
        }
    }
}
