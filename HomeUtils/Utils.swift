import Foundation

func parseJSON(_ data: Data) -> [String: Any]? {
  do {
    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
      return json
    }
  } catch let error {
    debugPrint(error.localizedDescription)
  }
  
  return nil
}

func stringifyJSON(_ json: [String: Any]) -> String? {
  do {
    let data = try JSONSerialization.data(withJSONObject: json)
    return data.string
  } catch let error {
    debugPrint(error.localizedDescription)
  }

  return nil
}

func timestampNow() -> UInt32 {
  return UInt32(Date().timeIntervalSince1970)
}
