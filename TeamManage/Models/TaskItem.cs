using TeamManage.Data;

namespace TeamManage.Models
{
    public class TaskItem
    {
        public int Id { get; set; }
        public int ModuleId { get; set; }
        public string Title { get; set; }
        public string? Note { get; set; }
        public ProcessStatus Status { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsDeleted { get; set; } = false;
        public string? AssignedUserId { get; set; }
        public ApplicationUser AssignedUser { get; set; }
        
        public Module Module { get; set; }
        public ICollection<Issue> Issues { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
