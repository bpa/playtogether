export function set(name, value) {
    let s = {};
    s[name] = value;
    this.setState(s);
    this.props.setConfig(name, value);
}

export class RadioButtonGroup extends React.Component {
    constructor(props) {
        super(props);
        let active = null;
        if (props.items) {
            active = props.items[0];
            if (active !== null && typeof active === 'object') {
                active = active.value;
            }
        }
        this.state = {active: active};
    }

    buttons(items) {
        return items.map((o, i) => {
            let l = o, v = o;
            if (o !== null && typeof o === 'object') {
                l = o.label;
                v = o.value;
            }
            let active = v === this.state.active ? ' active' : '';
            return <button key={v}
                className={'btn btn-success '+active}
                onClick={this.toggle.bind(this, v)}>{l}</button>;
        });
    }

    toggle(v) {
        this.setState({active: v});
        this.props.onChange(v);
    }

    render() { return (
<div className={'btn-group-vertical'}>
  {this.buttons(this.props.items)}
</div>
    )}
}

export class Toggle extends React.Component {
    constructor(props) {
        super(props);
        this.props = props;
        this.state = { on: props.on }
        this.props.onChange(props.name, props.on);
    }

    update(value) {
        this.props.onChange(this.props.name, value);
        this.setState({ on: value })
    }

    render() { return (
<button className={'btn btn-'+this.state.on ? 'success' : 'danger'} btn-checkbox>{this.state.on ? 'Yes' : 'No'}</button>
    )}
}
