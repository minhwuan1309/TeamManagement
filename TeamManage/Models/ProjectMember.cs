using TeamManage.Data;

namespace TeamManage.Models
{
    public class ProjectMember
    {
        public int Id { get; set; }
        public int ProjectId { get; set; }
        public string UserId { get; set; }
        public bool IsDeleted { get; set; } = false;
        public UserRole RoleInProject { get; set; }
        public Project Project { get; set; }
        public ApplicationUser User { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
