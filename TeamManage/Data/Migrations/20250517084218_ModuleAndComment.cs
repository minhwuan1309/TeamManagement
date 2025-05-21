using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class ModuleAndComment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Code",
                table: "Modules",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "ParentModuleId",
                table: "Modules",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CreatedById",
                table: "Issues",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TaskComment",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TaskItemId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskComment", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TaskComment_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TaskComment_TaskItems_TaskItemId",
                        column: x => x.TaskItemId,
                        principalTable: "TaskItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Modules_ParentModuleId",
                table: "Modules",
                column: "ParentModuleId");

            migrationBuilder.CreateIndex(
                name: "IX_Issues_CreatedById",
                table: "Issues",
                column: "CreatedById");

            migrationBuilder.CreateIndex(
                name: "IX_TaskComment_TaskItemId",
                table: "TaskComment",
                column: "TaskItemId");

            migrationBuilder.CreateIndex(
                name: "IX_TaskComment_UserId",
                table: "TaskComment",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Issues_AspNetUsers_CreatedById",
                table: "Issues",
                column: "CreatedById",
                principalTable: "AspNetUsers",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Modules_Modules_ParentModuleId",
                table: "Modules",
                column: "ParentModuleId",
                principalTable: "Modules",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Issues_AspNetUsers_CreatedById",
                table: "Issues");

            migrationBuilder.DropForeignKey(
                name: "FK_Modules_Modules_ParentModuleId",
                table: "Modules");

            migrationBuilder.DropTable(
                name: "TaskComment");

            migrationBuilder.DropIndex(
                name: "IX_Modules_ParentModuleId",
                table: "Modules");

            migrationBuilder.DropIndex(
                name: "IX_Issues_CreatedById",
                table: "Issues");

            migrationBuilder.DropColumn(
                name: "Code",
                table: "Modules");

            migrationBuilder.DropColumn(
                name: "ParentModuleId",
                table: "Modules");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "Issues");
        }
    }
}
