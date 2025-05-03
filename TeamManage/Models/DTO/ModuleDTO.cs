using TeamManage.Data;

namespace TeamManage.Models.DTO
{
    public class ModuleDTO
    {
        public int Id { get; set; }
        public int ProjectId { get; set; }
        public string? Name { get; set; }
        public ProcessStatus Status { get; set; }
        public List<MemberDTO>? Members { get; set; } = new List<MemberDTO>();
        public List<GetModuleWithTaskDTO>? Tasks { get; set; } = new List<GetModuleWithTaskDTO>();
        public bool IsDeleted { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class SimpleModuleDTO
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public ProcessStatus Status { get; set; }
        public int MemberCount { get; set; }
    }

}