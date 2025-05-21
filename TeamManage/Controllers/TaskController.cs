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
    public class TaskController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public TaskController(ApplicationDbContext context) => _context = context;
        
        // ====================== Get Tasks ======================

        [HttpGet("module/{moduleId}")]
        public async Task<IActionResult> GetTasksByModuleId(int moduleId)
        {
            var tasks = await _context.TaskItems
                        .Include(t => t.AssignedUser)
                        .Include(t => t.CurrentStep)
                        .Where(t => t.ModuleId == moduleId && !t.IsDeleted)
                        .ToListAsync();

            var result = tasks.Select(t=> new TaskDTO
            {
                Id = t.Id,
                ModuleId = t.ModuleId,
                Title = t.Title,
                Note = t.Note,
                Status = t.Status,
                StartDate = t.StartDate,
                EndDate = t.EndDate,
                IsDeleted = t.IsDeleted,
                CurrentStepId = t.CurrentStepId,
                CurrentStepName = t.CurrentStep?.StepName,
                AssignedUserId = t.AssignedUserId,
                AssignedUserName = t.AssignedUser?.FullName,
                CreatedAt = t.CreatedAt,
                UpdatedAt = t.UpdatedAt
            });

            return Ok(result);
        }
        
        [HttpGet("{id}")]
        public async Task<IActionResult> GetTaskById(int moduleId, int id)
        {
            var task = await _context.TaskItems
                .Include(t => t.AssignedUser)
                .Include(t => t.CurrentStep)
                .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);

            var result = new TaskDTO
            {
                Id = task.Id,
                ModuleId = task.ModuleId,
                Title = task.Title,
                Note = task.Note,
                Status = task.Status,
                StartDate = task.StartDate,
                EndDate = task.EndDate,
                IsDeleted = task.IsDeleted,
                AssignedUserId = task.AssignedUserId,
                AssignedUserName = task.AssignedUser?.FullName,
                CurrentStepId = task.CurrentStepId,
                CurrentStepName = task.CurrentStep?.StepName,
                CreatedAt = task.CreatedAt,
                UpdatedAt = task.UpdatedAt,
            };

            return Ok(result);
        }

        // ====================== Create Tasks ======================
        
        [HttpPost("create/{moduleId}")]
        public async Task<IActionResult> CreateTask(int moduleId, [FromBody] TaskDTO taskDTO)
        {
                // Validate input
            if (string.IsNullOrWhiteSpace(taskDTO.Title))
                return BadRequest("Tiêu đề task không được để trống.");
            if (taskDTO.StartDate == null)
                return BadRequest("Ngày bắt đầu không được để trống.");
            if (taskDTO.EndDate == null)
                return BadRequest("Ngày kết thúc không được để trống.");
            if (taskDTO.EndDate < taskDTO.StartDate)
                return BadRequest("Ngày kết thúc không được trước ngày bắt đầu.");

            //Validate AssignedUser
            var moduleMembers = await _context.ModuleMembers
                                .Where(m=> m.ModuleId == moduleId && !m.IsDeleted)
                                .Select(m => m.UserId)
                                .ToListAsync();
        
            if(taskDTO.AssignedUserId !=null && !moduleMembers.Contains(taskDTO.AssignedUserId))
                return BadRequest("Người được giao task phải là thành viên trong module.");

            var task = new TaskItem
            {
                ModuleId = moduleId,
                Title = taskDTO.Title,
                Note = taskDTO.Note,
                Status = 0,
                StartDate = taskDTO.StartDate,
                EndDate = taskDTO.EndDate,
                IsDeleted = false,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
                AssignedUserId = taskDTO.AssignedUserId
            };
            
            _context.TaskItems.Add(task);
            await _context.SaveChangesAsync();
            return Ok(new {message = "Tạo task thành công", task});
        }

        // ====================== Update Tasks ======================

        [HttpPut("update/{id}")]
        public async Task<IActionResult> UpdateTask(int id, [FromBody] TaskDTO taskDTO)
        {
            var task = await _context.TaskItems.FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);
            if (task == null)
                return NotFound("Không tìm thấy task.");

            //Validate input
            if(taskDTO.AssignedUserId != null)
            {
                var moduleMembers = await _context.ModuleMembers
                                    .Where(m=> m.ModuleId == task.ModuleId && !m.IsDeleted)
                                    .Select(m => m.UserId)
                                    .ToListAsync();

                if(!moduleMembers.Contains(taskDTO.AssignedUserId))
                    return BadRequest("Người được giao task phải là thông trong module.");
            }

            //Update từng field
            if(!string.IsNullOrWhiteSpace(taskDTO.Title))
                task.Title = taskDTO.Title;
            if(taskDTO.Note != null)
                task.Note = taskDTO.Note;
            if(Enum.IsDefined(typeof(ProcessStatus), taskDTO.Status))
                task.Status = taskDTO.Status;
            if(taskDTO.StartDate.HasValue)
                task.StartDate = taskDTO.StartDate;
            if(taskDTO.EndDate.HasValue)
                task.EndDate = taskDTO.EndDate;
            if(taskDTO.AssignedUserId != null)
                task.AssignedUserId = taskDTO.AssignedUserId;
            task.UpdatedAt = DateTime.Now;
            
            _context.TaskItems.Update(task);
            await _context.SaveChangesAsync();

            return Ok(new {message = "Cập nhật task thành công", task});
        }

        // ====================== Delete Tasks (Soft Delete) ======================

        [HttpDelete("delete/{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var task = await _context.TaskItems.FirstOrDefaultAsync(t => t.Id == id);
            if (task == null)
                return NotFound("Không tìm thấy task.");

            task.IsDeleted = !task.IsDeleted;
            task.UpdatedAt = DateTime.Now;
            
            _context.TaskItems.Update(task);
            await _context.SaveChangesAsync();

            return Ok(task.IsDeleted
                ? "Đã xóa task."
                : "Đã khôi phục task.");
        }

        [HttpDelete("hard-delete/{id}")] 
        public async Task<IActionResult> HardDeleteTask(int id)
        {
            var task = await _context.TaskItems.FirstOrDefaultAsync(t => t.Id == id);
            if (task == null)
                return NotFound("Không tìm thấy task.");

            _context.TaskItems.Remove(task);
            await _context.SaveChangesAsync();

            return Ok("Task đã được xóa.");
        }

        // ====================== Update Task Status ======================

        [HttpPut("update-status/{id}")] 
        public async Task<IActionResult> UpdateTaskStatus(int id, [FromQuery] ProcessStatus status)
        {
            var task = await _context.TaskItems.FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);
            if (task == null)
                return NotFound("Không tìm thấy task.");

            task.Status = status;
            task.UpdatedAt = DateTime.Now;

            _context.TaskItems.Update(task);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = $"Cập nhật trạng thái task -> {status}",
                taskId = task.Id,
                newStatus = task.Status.ToString()
            });
        }
    }
}
