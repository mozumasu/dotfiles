return {
  {
    "allaman/tf.nvim",
    ft = { "terraform", "hcl" },
    opts = {
      -- Browser command (default: auto-detect)
      -- browser_cmd = "open",

      -- Terraform CLI path (default: "terraform")
      -- terraform_cmd = "terraform",

      -- State browser settings
      state = {
        preview = true, -- Show resource preview
        confirm_delete = true, -- Confirm before deleting
      },
    },
    keys = {
      { "<leader>Td", "<cmd>TerraformDoc<cr>", desc = "Terraform Doc", ft = { "terraform", "hcl" } },
      { "<leader>Ts", "<cmd>TerraformState<cr>", desc = "Terraform State", ft = { "terraform", "hcl" } },
      { "<leader>Tv", "<cmd>TerraformValidate<cr>", desc = "Terraform Validate", ft = { "terraform", "hcl" } },
    },
  },
}
