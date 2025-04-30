using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class AddModuleMembersTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Modules_AspNetUsers_AssignedUserId",
                table: "Modules");

            migrationBuilder.DropIndex(
                name: "IX_Modules_AssignedUserId",
                table: "Modules");

            migrationBuilder.DropColumn(
                name: "AssignedUserId",
                table: "Modules");

            migrationBuilder.CreateTable(
                name: "ModuleMembers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ModuleId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ModuleMembers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ModuleMembers_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ModuleMembers_Modules_ModuleId",
                        column: x => x.ModuleId,
                        principalTable: "Modules",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ModuleMembers_ModuleId",
                table: "ModuleMembers",
                column: "ModuleId");

            migrationBuilder.CreateIndex(
                name: "IX_ModuleMembers_UserId",
                table: "ModuleMembers",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ModuleMembers");

            migrationBuilder.AddColumn<string>(
                name: "AssignedUserId",
                table: "Modules",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Modules_AssignedUserId",
                table: "Modules",
                column: "AssignedUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Modules_AspNetUsers_AssignedUserId",
                table: "Modules",
                column: "AssignedUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
