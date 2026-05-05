import Foundation

protocol NetworkService {
    func request<T: Decodable>(
        endpoint: EndPoint,
        completion: @escaping (Result<T, Error>) -> Void
    )
}

final class NetworkServiceImpl: NetworkService {
    func request<T: Decodable>(
        endpoint: EndPoint,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + endpoint.rawValue) else {
            DispatchQueue.main.async { completion(.failure(URLError(.badURL))) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }

                guard let data else {
                    DispatchQueue.main.async {
                        completion(.failure(URLError(.cannotDecodeContentData)))
                    }
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(decoded)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }.resume()
        }
    }
}

fileprivate enum Constants {
    static let baseURL = "https://dummyjson.com"
}
