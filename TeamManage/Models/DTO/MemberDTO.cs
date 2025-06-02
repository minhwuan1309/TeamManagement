using System.ComponentModel.DataAnnotations;

namespace TeamManage.Models.DTO
{
    public class MemberDTO
    {
        public string? FullName { get; set; }
        [Required(ErrorMessage = "UserId là bắt buộc")]
        public string UserId { get; set; }
        public string? Avatar { get; set; }
        public UserRole RoleInProject { get; set; }
    }

}
