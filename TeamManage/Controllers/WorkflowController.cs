using System.Security.Claims;
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
    [Authorize]
    public class WorkflowController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public WorkflowController(ApplicationDbContext context) => _context = context;


        //================= Create Workflow ================
        [HttpPost("create")]
        public async Task<IActionResult> CreateWorkflow([FromBody] CreateWorkflowDTO dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Name) || dto.ModuleId <= 0 || dto.Steps == null || !dto.Steps.Any())
                return BadRequest("Thông tin không hợp lệ!");

            var module = await _context.Modules.FirstOrDefaultAsync(x => x.Id == dto.ModuleId && !x.IsDeleted);
            if (module == null)
                return NotFound("Không tìm thấy module.");

            var workflow = new Workflow
            {
                Name = dto.Name,
                ModuleId = dto.ModuleId,
                Steps = new List<WorkflowStep>(),
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            foreach (var stepDto in dto.Steps.OrderBy(s => s.Order))
            {
                if (string.IsNullOrWhiteSpace(stepDto.StepName) || stepDto.Approvers == null || !stepDto.Approvers.Any())
                    continue; // bỏ qua bước không hợp lệ

                var step = new WorkflowStep
                {
                    StepName = stepDto.StepName,
                    Order = stepDto.Order,
                    Status = WorkflowStatus.None,
                    Approvals = stepDto.Approvers.Select(a => new WorkflowStepApproval
                    {
                        ApproverId = a.ApproverId
                    }).ToList()
                };
                workflow.Steps.Add(step);
            }

            _context.Workflows.Add(workflow);
            await _context.SaveChangesAsync();

            module.WorkflowId = workflow.Id;
            _context.Modules.Update(module);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo workflow thành công!", workflowId = workflow.Id });
        }


        //================= Get Workflow By Module ================
        [HttpGet("module/{moduleId}")]
        public async Task<IActionResult> GetWorkflowsByModule(int moduleId)
        {
            var workflow = await _context.Workflows
                                    .Include(w => w.Steps)
                                        .ThenInclude(s => s.Approvals)
                                            .ThenInclude(a => a.Approver)
                                    .FirstOrDefaultAsync(w => w.ModuleId == moduleId);

            if (workflow == null)
                return NotFound("Không tìm thấy workflow.");

            var result = new WorkflowResponseDTO
            {
                Id = workflow.Id,
                Name = workflow.Name,
                ModuleId = workflow.ModuleId,
                Steps = workflow.Steps
                        .OrderBy(s => s.Order)
                        .Select(s => new WorkflowStepDTO
                        {
                            Id = s.Id,
                            StepName = s.StepName,
                            Order = s.Order,
                            Status = s.Status.ToString().ToLower(),
                            Approvals = s.Approvals.Select(a => new WorkflowApproverDTO
                            {
                                ApproverId = a.ApproverId,
                                FullName = a.Approver.FullName,
                                Role = a.Approver.Role.ToString().ToLower(),
                                Avatar = a.Approver.Avatar
                            }).ToList()
                        }).ToList()
            };

            return Ok(result);
        }



        //=============== Duyệt step workflow ================
        [HttpPut("approve-step/{taskId}")]
        public async Task<IActionResult> ApproveStep(int taskId)
        {
            var task = await _context.TaskItems
                .Include(t => t.CurrentStep)
                    .ThenInclude(s => s.Approvals)
                .Include(t => t.Module)
                .ThenInclude(m => m.Workflow)
                    .ThenInclude(w => w.Steps)
                .FirstOrDefaultAsync(t => t.Id == taskId && !t.IsDeleted);

            if (task == null || task.CurrentStep == null)
                return NotFound("Không tìm thấy task hoặc bước hiện tại.");

            var userId = User.Identity?.Name;
            var isApprover = task.CurrentStep.Approvals.Any(a => a.ApproverId == userId);
            if (!isApprover)
                return Forbid("Bạn không có quyền duyệt bước này.");

            task.CurrentStep.Status = WorkflowStatus.Approved;
            task.CurrentStep.CompletedAt = DateTime.Now;

            var currentStepOrder = task.CurrentStep.Order;
            var nextStep = task.Module.Workflow.Steps
                .Where(s => s.Order > currentStepOrder)
                .OrderBy(s => s.Order)
                .FirstOrDefault();

            if (nextStep != null)
            {
                task.CurrentStepId = nextStep.Id;
            }
            else
            {
                task.Status = ProcessStatus.Done;
                task.CurrentStepId = null;
            }

            _context.TaskItems.Update(task);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Đã duyệt bước hiện tại",
                nextStep = nextStep?.StepName ?? "Đã hoàn thành toàn bộ workflow"
            });
        }


        //================= Gán workflow step cho task ==================
        [HttpPut("assign-step/{taskId}")]
        public async Task<IActionResult> AssignWorkflowStep(int taskId)
        {
            var task = await _context.TaskItems
                .Include(t => t.Module)
                    .ThenInclude(m => m.Workflow)
                        .ThenInclude(w => w.Steps)
                .FirstOrDefaultAsync(t => t.Id == taskId && !t.IsDeleted);

            if (task == null)
                return NotFound("Không tìm thấy task.");

            if (task.Module?.Workflow == null)
                return NotFound("Task không thuộc module có workflow.");

            if (task.CurrentStepId != null)
                return Ok(new { message = "Task đã được gán step workflow." });

            var firstStep = task.Module.Workflow.Steps.OrderBy(s => s.Order).FirstOrDefault();
            if (firstStep == null)
                return NotFound("Workflow không có bước nào để gán.");

            task.CurrentStepId = firstStep.Id;
            task.Status = ProcessStatus.InProgress;

            _context.TaskItems.Update(task);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = $"Đã gán bước '{firstStep.StepName}' trong 'workflow cho task",
                stepId = firstStep.Id,
                stepName = firstStep.StepName

            });
        }


        //================= Get Current Step of Task ================

        [HttpGet("step/{taskId}")]
        public async Task<IActionResult> GetCurrentStepOfTask(int taskId)
        {
            var task = await _context.TaskItems
                .Include(t => t.CurrentStep)
                    .ThenInclude(s => s.Approvals)
                        .ThenInclude(a => a.Approver)
                .FirstOrDefaultAsync(t => t.Id == taskId && !t.IsDeleted);

            if (task == null)
                return NotFound("Không tìm thấy task.");

            if (task.CurrentStep == null)
            {
                return Ok(new
                {
                    taskId = task.Id,
                    taskTitle = task.Title,
                    currentStep = (WorkflowStepDTO?)null
                });
            }

            var step = task.CurrentStep;

            var stepDto = new WorkflowStepDTO
            {
                Id = step.Id,
                StepName = step.StepName,
                Order = step.Order,
                Status = step.Status.ToString().ToLower(),
                Approvals = step.Approvals.Select(a => new WorkflowApproverDTO
                {
                    ApproverId = a.ApproverId,
                    FullName = a.Approver.FullName,
                    Avatar = a.Approver.Avatar,
                    Role = a.Approver.Role.ToString().ToLower()
                }).ToList()
            };

            return Ok(new
            {
                taskId = task.Id,
                taskTitle = task.Title,
                currentStep = stepDto
            });
        }


        //================= Update Step Status ================
        [HttpPut("update-step-status/{stepId}")]
        public async Task<IActionResult> UpdateStepStatus(int stepId, [FromBody] UpdateStepStatusDTO dto)
        {
            var step = await _context.WorkflowSteps
                .Include(a => a.Approvals)
                .FirstOrDefaultAsync(s => s.Id == stepId);

            if (step == null)
                return NotFound("Không tìm thấy workflow step.");

            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;


            if (!step.Approvals.Any(a => a.ApproverId == userId))
                return StatusCode(403, "Bạn không có quyền duyệt bước này.");


            step.Status = dto.NewStatus;
            if (dto.NewStatus == WorkflowStatus.Approved)
            {
                step.CompletedAt = DateTime.Now;
            }

            _context.WorkflowSteps.Update(step);
            await _context.SaveChangesAsync();
            return Ok(new
            {
                message = $"Cập nhật trạng thái bước '{step.StepName}' thành công!",
                stepId = step.Id,
                newStatus = step.Status.ToString().ToLower()
            });
        }

        //================= Update Approver ================
        [HttpPut("step/{stepId}/approver")]
        public async Task<IActionResult> UpdateApprover(int stepId, [FromBody] WorkflowApproverInputDTO dto)
        {
            var step = await _context.WorkflowSteps
                .Include(s => s.Approvals)
                .FirstOrDefaultAsync(s => s.Id == stepId);

            if(step == null)
                return NotFound("Không tìm thấy workflow step.");

            _context.WorkflowStepApprovals.RemoveRange(step.Approvals);
            var newApprovals = new WorkflowStepApproval
            {
                ApproverId = dto.ApproverId,
                WorkflowStepId = stepId
            };

            _context.WorkflowStepApprovals.AddRange(newApprovals);
            await _context.SaveChangesAsync();
            return Ok(new
            {
                message = $"Cập nhật người duyệt '{step.StepName}' thanh cong!",
                approverId = dto.ApproverId
            });
        }
    }
}


