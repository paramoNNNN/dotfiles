{ inputs, ... }: {
	imports = [
		inputs.nixvim.homeManagerModules.nixvim
		./plugins
	];

	home.shellAliases.v = "nvim";

	programs.nixvim = {
		enable = true;
		defaultEditor = true;
		luaLoader.enable = true;
	};
}
