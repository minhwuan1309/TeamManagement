namespace TeamManage.Models
{
    public class WorkflowStep
    {
        public int Id { get; set; }
        public int WorkflowId { get; set; }
        public string StepName { get; set; }
        public int Order { get; set; }
        public bool IsDeleted { get; set; } = false;
        public Workflow Workflow { get; set; }
        public ICollection<WorkflowStepApproval> Approvals { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
