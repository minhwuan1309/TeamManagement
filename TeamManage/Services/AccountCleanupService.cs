using Microsoft.AspNetCore.Identity;
using TeamManage.Data;

namespace TeamManage.Services
{
    public class AccountCleanupService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        public AccountCleanupService(IServiceScopeFactory scopeFactory) => _scopeFactory = scopeFactory;
    
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while(!stoppingToken.IsCancellationRequested)
            {
                using var scope = _scopeFactory.CreateScope();
                var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

                var users = userManager.Users.Where(u => !u.IsVerified && u.VerificationExpiry < DateTime.UtcNow);
                foreach(var user in users)
                {
                    await userManager.DeleteAsync(user);
                }
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
