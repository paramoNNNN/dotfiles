{
	programs.nixvim = {
		plugins.which-key.settings.spec = [
		{
			__unkeyed-1 = [
			{
				__unkeyed-1 = "<leader>d";
				group = "Neotree";
			}
			{
				__unkeyed-1 = "<leader>dt";
				__unkeyed-2 = "<Cmd>Neotree toggle<CR>";
				desc = "Toggle";
			}
			];
			mode = [
				"n"
			];
		}
		];

		plugins.neo-tree = {
			enable = true;
			# filesystem = {
			# 	filtered_items = {
			# 		hide_dotfiles = false;
			# 	};
			# 	follow_current_file = {
			# 		enable = true;
			# 	};
			# };
			closeIfLastWindow = true;
			window = {
				position = "right";
			};
		};
	};
}
