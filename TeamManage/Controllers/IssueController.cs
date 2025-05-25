using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeamManage.Data;
using TeamManage.Models;
using TeamManage.Models.DTO;
using TeamManage.Services.CloudinaryConfig;

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
                        .Include(i => i.Files)
                        .Include(i => i.CreatedBy)
                        .Where(i => i.TaskItemId == taskId && !i.IsDeleted)
                        .ToListAsync();

            var result = issues.Select(issue => new IssueDetailDTO
            {
                Id = issue.Id,
                Title = issue.Title,
                Description = issue.Description,
                Status = issue.Status,
                CreatedAt = issue.CreatedAt,
                UpdatedAt = issue.UpdatedAt,
                CreatedByName = issue.CreatedBy?.FullName,
                Files = issue.Files.Select(f => new IssueFileDTO
                {
                    Url = f.Url,
                    Name = f.Name,
                    FileType = f.FileType
                }).ToList()
            });

            return Ok(result);
        }

        // ====================== Get Issue By Id ======================
        [HttpGet("{id}")]
        public async Task<IActionResult> GetIssueById(int id)
        {
            var issue = await _context.Issues
                .Include(i => i.Files)
                .Include(i => i.CreatedBy)
                .FirstOrDefaultAsync(i => i.Id == id && !i.IsDeleted);
            if (issue == null)
                return NotFound("Không tìm thấy issue.");

            var result = new IssueDetailDTO
            {
                Id = issue.Id,
                Title = issue.Title,
                Description = issue.Description,
                Status = issue.Status,
                CreatedAt = issue.CreatedAt,
                UpdatedAt = issue.UpdatedAt,
                CreatedByName = issue.CreatedBy?.FullName,
                Files = issue.Files.Select(f => new IssueFileDTO
                {
                    Url = f.Url,
                    Name = f.Name,
                    FileType = f.FileType
                }).ToList()
            };
            
            return Ok(result);
        }
        

        // ====================== Create Issue ======================
        [HttpPost("task/create/{taskId}")]
        public async Task<IActionResult> CreateIssue([FromForm] string title, [FromForm] string description, int taskId, [FromForm] List<IFormFile>? files, [FromServices] CloudinaryService cloudinary)
        {
            var task = await _context.TaskItems.FirstOrDefaultAsync(t => t.Id == taskId && !t.IsDeleted);
            if (task == null)
                return NotFound("Không tìm thấy task.");

            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrWhiteSpace(title))
                return BadRequest("Tiêu đề không được để trống!");
            if (string.IsNullOrWhiteSpace(description))
                return BadRequest("Mô tả không được để trống!");

            var issue = new Issue
            {
                Title = title,
                Description = description,
                IsDeleted = false,
                Status = ProcessStatus.None,
                TaskItemId = taskId,
                CreatedById = userId,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };
            if (files != null && files.Count > 0)
            {
                foreach (var file in files)
                {
                    var uploadResult = await cloudinary.UploadFileAsync(file);
                    if (uploadResult != null)
                    {
                        issue.Files.Add(new IssueFile
                        {
                            Url = uploadResult.Value.url,
                            Name = file.FileName,
                            FileType = uploadResult.Value.type
                        });
                    }
                }
            }

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


            if (issueDTO.Description != null && !string.IsNullOrWhiteSpace(issueDTO.Description))
                issue.Description = issueDTO.Description;


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
