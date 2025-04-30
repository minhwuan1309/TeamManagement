using System.ComponentModel.DataAnnotations;

namespace TeamManage.Models.DTO
{
    public class MemberDTO
    {
        public string UserId { get; set; }
        public UserRole RoleInProject { get; set; }
    }

}
