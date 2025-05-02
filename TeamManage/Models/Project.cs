using System.ComponentModel.DataAnnotations;

namespace TeamManage.Models
{
    public class Project
    {
        public int Id { get; set; }
        [Required(ErrorMessage = "Tên project không được để trống")]
        public string Name { get; set; }
        [Required(ErrorMessage = "Mô tả project không được để trống")]
        public string Description { get; set; }
        public DateTime StartDate { get; set; }
        public bool IsDeleted { get; set; } = false;
        public ICollection<ProjectMember> Members { get; set; }
        public ICollection<Module> Modules { get; set; }
        public ICollection<Workflow> Workflows { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
