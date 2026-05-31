import 'package:xml/xml.dart';

extension XmlLocalNameQueries on XmlNode {
  Iterable<XmlElement> descendantsByLocalName(String localName) {
    return descendantElements.where(
      (element) => element.name.local == localName,
    );
  }

  Iterable<XmlElement> childrenByLocalName(String localName) {
    return childElements.where((element) => element.name.local == localName);
  }

  XmlElement? firstDescendantByLocalName(String localName) {
    for (final element in descendantElements) {
      if (element.name.local == localName) {
        return element;
      }
    }
    return null;
  }
}

extension XmlLocalAttribute on XmlElement {
  String? attributeByLocalName(String localName) {
    for (final attribute in attributes) {
      if (attribute.name.local == localName) {
        return attribute.value;
      }
    }
    return null;
  }
}
