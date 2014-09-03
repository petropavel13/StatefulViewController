//
//  StatefulViewController.swift
//  StatefulViewController
//
//  Created by Alexander Schuch on 30/07/14.
//  Copyright (c) 2014 Alexander Schuch. All rights reserved.
//

import UIKit

/// Represents all possible states of this view controller
public enum StatefulViewControllerState: String {
	case Content = "content"
	case Loading = "loading"
	case Error = "error"
	case Empty = "empty"
}

///
/// A view controller subclass that presents placeholder views based on content, loading, error or empty states.
///
public class StatefulViewController: UIViewController {
	lazy private var stateMachine: ViewStateMachine = ViewStateMachine(view: self.view)
	
	/// The current state of the view controller.
	/// All states other than `Content` imply that there is a placeholder view shown.
	var currentState: StatefulViewControllerState {
		switch stateMachine.currentState {
			case .None: return .Content
			case .View(let viewKey): return StatefulViewControllerState.fromRaw(viewKey)!
		}
	}


	// MARK: Views
	
	/// The loading view is shown when the `startLoading` method gets called
	var loadingView: UIView! {
		didSet { setPlaceholderView(loadingView, forState: .Loading) }
	}
	
	/// The error view is shown when the `endLoading` method returns an error
	var errorView: UIView! {
		didSet { setPlaceholderView(errorView, forState: .Error) }
	}
	
	/// The empty view is shown when the `hasContent` method returns false
	var emptyView: UIView! {
		didSet { setPlaceholderView(emptyView, forState: .Empty) }
	}

	
	// MARK: UIViewController
	
	required public init(coder aDecoder: NSCoder)  {
		super.init(coder: aDecoder)
	}
	
	override public func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		transitionViewStates(animated: false)
	}
	
	
	// MARK: Start and stop loading
	
	/// Transitions the controller to the loading state and shows
	/// the loading view if there is no content shown already.
	///
	/// :param: animated	true if the switch to the placeholder view should be animated, false otherwise
	///
	public func startLoading(animated: Bool = false) {
		transitionViewStates(loading: true, animated: animated)
	}
	
	/// Ends the controller's loading state.
	/// If an error occured, the error view is shown.
	/// If the `hasContent` method returns false after calling this method, the empty view is shown.
	///
	/// :param: animated	true if the switch to the placeholder view should be animated, false otherwise
	/// :param: error		An error that might have occured whilst loading
	///
	public func endLoading(animated: Bool = true, error: NSError? = nil) {
		transitionViewStates(loading: false, animated: animated, error: error)
	}
	
	
	// MARK: Update view states
	
	/// Transitions the view to the appropriate state based on the `loading` and `error`
	/// input parameters and shows/hides corresponding placeholder views.
	///
	/// :param: loading		true if the controller is currently loading
	/// :param: error		An error that might have occured whilst loading
	/// :param: animated	true if the switch to the placeholder view should be animated, false otherwise
	///
	public func transitionViewStates(loading: Bool = false, error: NSError? = nil, animated: Bool = true) {
		// Update view for content (i.e. hide all placeholder views)
		if hasContent() {
			if let e = error {
				// show unobstrusive error
				handleErrorWhenContentAvailable(e)
			}
			stateMachine.transitionToState(.None, animated: animated)
			return
		}
		
		// Update view for placeholder
		var newState: StatefulViewControllerState = .Empty
		if loading {
			newState = .Loading
		} else if let e = error {
			newState = .Error
		}
		stateMachine.transitionToState(.View(newState.toRaw()), animated: animated)
	}
	
	
	// MARK: Helper
	
	private func setPlaceholderView(view: UIView, forState state: StatefulViewControllerState) {
		stateMachine[state.toRaw()] = view
	}
}


// MARK: Overridable methods

extension StatefulViewController {
	/// Can be overridden by a subclass of StatefulViewController.
	/// Return true if content is available in your controller.
	///
	/// :returns: true if there is content available in your controller.
	///
	func hasContent() -> Bool { return true }
	
	/// Can be overridden by a subclass of StatefulViewController.
	/// This method is called if an error occured, but `hasContent` returns true.
	/// You would typically display some error message that is easily dismissable 
	/// for the user to continue browsing content.
	/// 
	/// :param: error	The error that occured
	///
	func handleErrorWhenContentAvailable(error: NSError) { }
}
