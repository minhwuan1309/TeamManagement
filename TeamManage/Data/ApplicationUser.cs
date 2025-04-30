using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;
using TeamManage.Models;

namespace TeamManage.Data
{
    public class ApplicationUser : IdentityUser
    {
        [Required]
        public string FullName { get; set; }

        [Required, Phone]
        public string Phone { get; set; }

        public string? Avatar { get; set; }

        public UserRole Role { get; set; }

        public bool IsActive { get; set; } = true;
        public bool IsDeleted { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        public ICollection<ProjectMember> ProjectMemberships { get; set; }
        public ICollection<WorkflowStepApproval> Approvals { get; set; }

    }
}
