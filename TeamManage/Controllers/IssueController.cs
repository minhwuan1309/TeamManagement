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
    public class IssueController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public IssueController(ApplicationDbContext context) => _context = context;

        // ====================== Get Issues By Task ======================
        [HttpGet("task/{taskId}")]
        public async Task<IActionResult> GetIssuesByTask(int taskId)
        {
            var issues = await _context.Issues
                        .Where(i => i.TaskItemId == taskId && !i.IsDeleted)
                        .ToListAsync();

            return Ok(issues);
        }

        // ====================== Get Issue By Id ======================
        [HttpGet("{id}")]
        public async Task<IActionResult> GetIssueById(int id)
        {
            var issue = await _context.Issues.FirstOrDefaultAsync(i => i.Id == id && !i.IsDeleted);
            return Ok(issue);
        }

        // ====================== Create Issue ======================
        [HttpPost("task/create/{taskId}")]
        public async Task<IActionResult> CreateIssue([FromBody] IssueDTO issueDTO, int taskId)
        {
            var task = await _context.TaskItems.FirstOrDefaultAsync(t => t.Id == taskId && !t.IsDeleted);
            if (task == null)
                return NotFound("Không tìm thấy task.");

            if(string.IsNullOrWhiteSpace(issueDTO.Title))
                return BadRequest("Tiêu đề không được để trống!");
            if(string.IsNullOrWhiteSpace(issueDTO.Description))
                return BadRequest("Mô tả không được để trống!");

            var issue = new Issue
            {
                
                Title = issueDTO.Title,
                Description = issueDTO.Description,
                IsDeleted = false,
                Status = ProcessStatus.None,
                TaskItemId = taskId,
                Image = issueDTO.Image,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.Issues.Add(issue);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã tạo issue mới", issue });
        }

        // ====================== Update Issue ======================
        [HttpPut("task/update/{id}")]
        public async Task<IActionResult> UpdateIssue(int id, [FromBody] IssueDTO issueDTO)
        {
            var issue = await _context.Issues.FirstOrDefaultAsync(i => i.Id == id && !i.IsDeleted);
            if (issue == null)
                return NotFound("Không tìm thấy issue.");

            if (issueDTO.Title != null && !string.IsNullOrWhiteSpace(issueDTO.Title))
                issue.Title = issueDTO.Title;

            if (issueDTO.Description != null && !string.IsNullOrWhiteSpace(issueDTO.Description))
                issue.Description = issueDTO.Description;

            if (issueDTO.Image != null && !string.IsNullOrWhiteSpace(issueDTO.Image))
                issue.Image = issueDTO.Image;
            issue.UpdatedAt = DateTime.Now;

            _context.Issues.Update(issue);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã cập nhật issue", issue });
        }

        [HttpDelete("delete/{id}")] 
        public async Task<IActionResult> DeleteIssue(int id)
        {
            var issue = await _context.Issues.FirstOrDefaultAsync(i => i.Id == id && !i.IsDeleted);
            if (issue == null)
                return NotFound("Không tìm thấy issue.");

            issue.IsDeleted = !issue.IsDeleted;
            issue.UpdatedAt = DateTime.Now;

            _context.Issues.Update(issue);
            await _context.SaveChangesAsync();

            return Ok(issue.IsDeleted
                ? "Đã xóa issue."
                : "Đã khôi phục issue.");
        }

        [HttpPut("update-status/{id}")]
        public async Task<IActionResult> UpdateIssueStatus(int id, [FromQuery] ProcessStatus status)
        {
            var issue = await _context.Issues.FirstOrDefaultAsync(i => i.Id == id && !i.IsDeleted);
            if (issue == null)
                return NotFound("Không tìm thấy issue.");

            issue.Status = status;
            issue.UpdatedAt = DateTime.Now;

            _context.Issues.Update(issue);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = $"Cập nhật trạng thái issue -> {status}",
                issueId = issue.Id,
                newStatus = issue.Status.ToString()
            });
        }
    }
}
