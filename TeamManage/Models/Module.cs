using TeamManage.Data;

namespace TeamManage.Models
{
    public class Module
    {
        public int Id { get; set; }
        public int ProjectId { get; set; }
        public string Name { get; set; }
        public ProcessStatus Status { get; set; }
        public bool IsDeleted { get; set; } = false;

        public ICollection<ModuleMember> ModuleMembers { get; set; }
        public int? WorkflowId { get; set; }
        public Workflow Workflow { get; set; }

        public Project Project { get; set; }
        public ICollection<TaskItem> Tasks { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
