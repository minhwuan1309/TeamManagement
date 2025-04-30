using TeamManage.Data;

namespace TeamManage.Models
{
    public class ModuleMember
    {
        public int Id { get; set; }
        public int ModuleId { get; set; }
        public string UserId { get; set; }
        public bool IsDeleted { get; set; } = false;

        public Module Module { get; set; }
        public ApplicationUser User { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
