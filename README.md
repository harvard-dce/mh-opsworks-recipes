# mh-opsworks-recipes-cookbook

A custom cookbook in support of mh-opsworks

## Supported Platforms

Ubuntu 14.04 LTS, and more specifically amazon aws

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['mh-opsworks-recipes']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### mh-opsworks-recipes::default

Include `mh-opsworks-recipes` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[mh-opsworks-recipes::default]"
  ]
}
```


## Contributors

* Dan Collis-Puro - [djcp](https://github.com/djcp)

## Development

* Create a branch off the develop branch
* Edit your cluster config to use this branch in your development cluster
* Make your changes and push them to your recipe branch
* Update your cluster's chef recipes and redeploy to run them. If your recipe
  isn't run during the deploy lifecycle, then run it manually to test.
* Work on your feature until it's ready to be merged into the develop branch.
* Be sure to update the "To be released" section of the CHANGELOG.md file with
  a description of your change, and whether or not it requires a manual recipe
  invocation. If your change runs as part of the deploy lifecycle, it will be run
  the next time the main app is deployed to a cluster and therefore does not
  require a manual chef recipe invocation.
* Rebase against develop and submit a pull request off of develop.

## Releasing new chef recipes

* Update CHANGELOG.md to collapse all "To be released" changes under a new
  version, following [semver](http://semver.org).
* Rebase develop onto master.
* Merge develop into master.
* Tag the release on master.
* Push the tag to the remote via `git push --tags`

## License

This project is under an Apache 2.0 license. Please see LICENSE.txt for details.

## Copyright

2015 President and Fellows of Harvard College
