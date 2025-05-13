using System.ComponentModel.DataAnnotations;

namespace TeamManage.Models.DTO
{

    public class CreateWorkflowDTO
    {
        public string Name { get; set; }
        public int ModuleId { get; set; }
        public List<CreateWorkflowStepDTO> Steps { get; set; }
    }

    public class CreateWorkflowStepDTO
    {
        public string StepName { get; set; }
        public int Order { get; set; }
        public List<WorkflowApproverInputDTO> Approvers { get; set; } = new();
    }

    public class WorkflowApproverInputDTO
    {
        public string ApproverId { get; set; }
    }



    public class WorkflowStepDTO
    {
        public int Id { get; set; }
        public string StepName { get; set; }
        public int Order { get; set; }
        public string Status { get; set; }
        public List<WorkflowApproverDTO> Approvals { get; set; }
    }
    public class WorkflowApproverDTO
    {
        public string ApproverId { get; set; }
        public string FullName { get; set; }
        public string Role { get; set; }
        public string Avatar { get; set; }
    }


    public class WorkflowResponseDTO
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int ModuleId { get; set; }
        public List<WorkflowStepDTO> Steps { get; set; }
    }

}


