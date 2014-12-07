import PerField from 'coalesce/merge/per_field';

export default class EmberPerField extends PerField {

  // override to fix coalesce's version that doesnt work with ember > 1.8
  // can only set and get via set() and get() and not directly
  mergeProperty(ours, ancestor, theirs, name) {
    var oursValue = ours.get(name),
        ancestorValue = ancestor.get(name),
        theirsValue = theirs.get(name);

    if(!ours.isFieldLoaded(name)) {
      if(theirs.isFieldLoaded(name)) {
        ours.set(name, copy(theirsValue));
      }
      return;
    }
    if(!theirs.isFieldLoaded(name) || isEqual(oursValue, theirsValue)) {
      return;
    }
    // if the ancestor does not have the property loaded we are
    // performing a two-way merge and we just pick theirs
    if(!ancestor.isFieldLoaded(name) || isEqual(oursValue, ancestorValue)) {
      ours.set(name, copy(theirsValue));
    } else {
      // NO-OP
    }
  }
}