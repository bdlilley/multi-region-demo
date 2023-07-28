package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/bensolo-io/multi-region-demo/lambda-redis-promoter/pkg/awslambda"
	"github.com/bensolo-io/multi-region-demo/lambda-redis-promoter/pkg/config"
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"
)

var cfg config.Config = config.Config{}

var rootCmd = &cobra.Command{
	Use:   "redis-promoter",
	Short: "redis-promoter - detects regional dns failover and promotes secondary redis instances to primary",
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		cfg.DnsName = strings.TrimRight(cfg.DnsName, ".")
		return nil
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		handler, err := awslambda.NewHandlerFunc(cfg)
		if err != nil {
			return err
		}

		if os.Getenv("AWS_LAMBDA_RUNTIME_API") != "" {
			log.Info().Msg("detected AWS lambda runtime, starting lambda handler")
			lambda.Start(handler)
			return nil
		}

		log.Info().Msg("no aws runtime detected, invoking handler directly")
		return handler(nil)
	},
}

func Execute() {
	// Z10116174WM8F5NP9R1Z
	rootCmd.PersistentFlags().StringVar(&cfg.HostedZoneID, "hz", "", "hosted zone id")
	rootCmd.PersistentFlags().StringVarP(&cfg.DnsName, "dns-name", "d", "", "dns name to watch for changes")
	rootCmd.PersistentFlags().StringVarP(&cfg.GlobalDataStoreId, "global-data-store-id", "g", "", "id of the elasticache global data store")
	// rootCmd.Flags().StringArrayVarP(&config.Scopes, "scopes", "s", []string{}, "add jwt scopes")
	// rootCmd.Flags().StringArrayVarP(&config.Audiences, "audiences", "a", []string{"https://fake-resource.solo.io"}, "jwt audience")
	// rootCmd.Flags().StringVarP(&config.Exp, "expires-in", "e", "8766h", "expires duration (uses https://pkg.go.dev/time#ParseDuration)")
	// rootCmd.Flags().StringVarP(&config.Sub, "subject", "u", "glooey@solo.io", "jwt subject")
	// rootCmd.Flags().BoolVarP(&config.OutputJSON, "json", "j", false, "output full token signed details as JSON")
	// rootCmd.Flags().StringVarP(&config.Provider, "provider", "p", "provider1", "provider to use (provider1, provider2)")

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Whoops. There was an error while executing your CLI '%s'", err)
		os.Exit(1)
	}
}
