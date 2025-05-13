using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class dropColumnInWorkflows : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Workflows_Projects_ProjectId",
                table: "Workflows");

            migrationBuilder.DropIndex(
                name: "IX_Workflows_ProjectId",
                table: "Workflows");

            migrationBuilder.DropColumn(
                name: "ProjectId",
                table: "Workflows");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ProjectId",
                table: "Workflows",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Workflows_ProjectId",
                table: "Workflows",
                column: "ProjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Workflows_Projects_ProjectId",
                table: "Workflows",
                column: "ProjectId",
                principalTable: "Projects",
                principalColumn: "Id");
        }
    }
}
