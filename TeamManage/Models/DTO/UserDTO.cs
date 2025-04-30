using System.ComponentModel.DataAnnotations;

namespace TeamManage.Models.DTO
{
    public class UserDTO
    {
        public string? Id { get; set; }

        [Required(ErrorMessage = "Tên không được để trống")]
        public string? FullName { get; set; }

        [Required(ErrorMessage = "Email không được để trống")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string? Email { get; set; }

        [Required(ErrorMessage = "Sđt không được để trống")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
        public string? Phone { get; set; }

        //Password
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
        [Required(ErrorMessage = "Mật khẩu không được để trống")]
        public string? Password { get; set; }
        public string? Avatar { get; set;}
        public UserRole Role { get; set; } 
        public bool IsDeleted { get; set; } = false;
        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
