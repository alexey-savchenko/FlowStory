//
//  AnyPublisher+Create.swift
//  StoryCropper
//
//  Created by Alexey Savchenko on 10.03.2021.
//

import Combine

struct AnyObserver<Output, Failure: Error> {
  let onNext: ((Output) -> Void)
  let onError: ((Failure) -> Void)
  let onComplete: (() -> Void)
}

struct Disposable {
  let dispose: () -> Void
  
  static let create = Disposable(dispose: {})
}

extension AnyPublisher {
  static func create(subscribe: @escaping (AnyObserver<Output, Failure>) -> Disposable) -> Self {
    let subject = PassthroughSubject<Output, Failure>()
    var disposable: Disposable?
    return subject
      .handleEvents(receiveSubscription: { subscription in
        disposable = subscribe(AnyObserver(
          onNext: { output in subject.send(output) },
          onError: { failure in subject.send(completion: .failure(failure)) },
          onComplete: { subject.send(completion: .finished) }
        ))
      }, receiveCancel: { disposable?.dispose() })
      .eraseToAnyPublisher()
  }
}
