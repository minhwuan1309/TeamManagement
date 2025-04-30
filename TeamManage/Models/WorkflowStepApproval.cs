using TeamManage.Data;

namespace TeamManage.Models
{
    public class WorkflowStepApproval
    {
        public int Id { get; set; }
        public int WorkflowStepId { get; set; }
        public string ApproverId { get; set; } // Người duyệt
        public WorkflowStep WorkflowStep { get; set; }
        public ApplicationUser Approver { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
