using TeamManage.Data;

namespace TeamManage.Models
{
    public class Module
    {
        //các field cơ bản 
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public int ProjectId { get; set; }
        public Project Project { get; set; }

        //phân cấp module
        public int? ParentModuleId { get; set; }
        public Module ParentModule { get; set; }
        public ICollection<Module> SubModules { get; set; }

        //trạng thái module
        public ProcessStatus Status { get; set; }
        public bool IsDeleted { get; set; } = false;

        //Workflow
        public int? WorkflowId { get; set; }
        public Workflow Workflow { get; set; }

        //ICollection
        public ICollection<ModuleMember> ModuleMembers { get; set; }
        public ICollection<TaskItem> Tasks { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
