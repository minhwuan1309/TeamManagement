namespace TeamManage.Models
{
    public class WorkflowStep
    {
        public int Id { get; set; }
        public int WorkflowId { get; set; }
        public string StepName { get; set; }
        public int Order { get; set; }
        public bool IsDeleted { get; set; } = false;
        public WorkflowStatus Status { get; set; } = WorkflowStatus.None;
        public DateTime? CompletedAt { get; set; }
        public ICollection<WorkflowStepApproval> Approvals { get; set; }
    }
}
