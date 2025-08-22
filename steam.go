package steam

type Steam interface{}

type SteamClient struct {
}

func New() Steam {
	return &SteamClient{}
}
