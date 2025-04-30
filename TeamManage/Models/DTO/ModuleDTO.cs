using TeamManage.Data;

namespace TeamManage.Models.DTO
{
    public class ModuleDTO
    {
        public int Id { get; set; }
        public int ProjectId { get; set; }
        public string? Name { get; set; }
        public ProcessStatus Status { get; set; }
        public List<string> MemberIds { get; set; } = new List<string>();
        public List<string>? MemberNames { get; set; }
        public bool IsDeleted { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}