using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeamManage.Data;
using TeamManage.Helpers;

namespace TeamManage.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SearchController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public SearchController(ApplicationDbContext context) => _context = context;
        [HttpGet]
        public async Task<IActionResult> Search([FromQuery] string query)
        {
            if (string.IsNullOrWhiteSpace(query))
                return Ok(new List<object>());

            query = StringHelper.RemoveDiacritics(query);
            // Lấy data trước

            var allModules = await _context.Modules
                .Where(m => !m.IsDeleted)
                .Include(m => m.Project).Where(m => !m.Project.IsDeleted)
                .ToListAsync();

            var allTasks = await _context.TaskItems
                .Where(t => !t.IsDeleted)
                .Include(t => t.Module).Where(t => !t.Module.IsDeleted)
                .ToListAsync();

            var allIssue = await _context.Issues
                .Where(i => !i.IsDeleted)
                .Include(i => i.TaskItem).Where(i => !i.TaskItem.IsDeleted)
                .ToListAsync();


            //So sánh ký tự

            var module = allModules
                .Where(m => StringHelper.RemoveDiacritics(m.Name).Contains(query))
                .Select(m => new
                {
                    type = "module",
                    id = m.Id,
                    title = m.Name,
                    description = $"Dự án: {m.Project.Name}"
                }).ToList();

            var task = allTasks
                .Where(t => StringHelper.RemoveDiacritics(t.Title).Contains(query))
                .Select(t => new
                {
                    type = "task",
                    id = t.Id,
                    title = t.Title,
                    description = $"Module: {t.Module.Name}"
                }).ToList();

            var issue = allIssue
                .Where(i => StringHelper.RemoveDiacritics(i.Title).Contains(query))
                .Select(i => new
                {
                    type = "issue",
                    id = i.Id,
                    title = i.Title,
                    description = $"Task: {i.TaskItem.Title}"
                }).ToList();


            var result = module.Concat<object>(task)
                                .Concat(issue)
                                .ToList();
            return Ok(result);
        }
    }
}
