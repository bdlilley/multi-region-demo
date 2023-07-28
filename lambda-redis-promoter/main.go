package main

import (
	"github.com/bensolo-io/multi-region-demo/lambda-redis-promoter/cmd"
	"github.com/rs/zerolog"
)

func init() {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	zerolog.SetGlobalLevel(zerolog.DebugLevel)
}

func main() {
	cmd.Execute()
}
