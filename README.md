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

## License

This project is under an Apache 2.0 license. Please see LICENSE.txt for details.

## Copyright

2015 President and Fellows of Harvard College
