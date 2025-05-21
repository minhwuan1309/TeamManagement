using TeamManage.Data;

namespace TeamManage.Models
{
    public class TaskItem
    {
        // Các field cơ bản
        public int Id { get; set; }
        public int ModuleId { get; set; }
        public string Title { get; set; }
        public string? Note { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        // Trạng thái 
        public ProcessStatus Status { get; set; }
        public bool IsDeleted { get; set; } = false;

        // Assign
        public string? AssignedUserId { get; set; }
        public ApplicationUser AssignedUser { get; set; }


        // ICollection
        public Module Module { get; set; }
        public ICollection<Issue> Issues { get; set; }
        public ICollection<TaskComment> Comments { get; set; }

        // Workflow
        public int? CurrentStepId { get; set; }
        public WorkflowStep CurrentStep { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
