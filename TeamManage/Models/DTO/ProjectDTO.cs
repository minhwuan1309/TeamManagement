using System.ComponentModel.DataAnnotations;

namespace TeamManage.Models.DTO
{
    public class ProjectDTO
    {
        public int? Id { get; set; }
        [Required(ErrorMessage = "Tên project không được để trống")]
        public string? Name { get; set; }

        [Required(ErrorMessage = "Mô tả project không được để trống")]
        public string? Description { get; set; }

        [DataType(DataType.Date)]
        public DateTime Deadline { get; set; }

        public bool IsDeleted { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public DateTime UpdatedAt { get; set; } = DateTime.Now;
        public List<MemberDTO> Members { get; set; } = new();
    }
}
