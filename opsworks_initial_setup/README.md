
## opsworks_initial_setup overrides

This "cookbook" extends a built-in Opsworks cookbook and overrides the `package_ntpd` recipe. This was the only workaround I could figure out for a buggish thing with opsworks and amazon linux. The instructions in [Set the time for your Linux instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html) say to uninstall ntpd and install cronyd instead. Well, the built-in opsworks cookbook insists on installing ntpd during instance setup (which conflicts with cronyd. So we need to override that ntpd recipe and make it a no-op.
