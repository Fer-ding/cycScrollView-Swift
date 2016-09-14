//
//  DYHCycleScrollView.swift
//  OolaGongYiSwift
//
//  Created by YueHui on 16/9/6.
//  Copyright © 2016年 LeapDing. All rights reserved.
//

import UIKit

enum DYHPageControllerState {
    case None
    case Left
    case Center
    case Right
}

class DYHCycleScrollView: UIView {
    
    var allImageUrls: [String] = []
    var animationDuration: NSTimeInterval!
    var autoScroll = true {
        didSet {
            if !autoScroll {
                cancelTimer()
            }
        }
    }
    
    var pageContollerSate: DYHPageControllerState = .None {
        didSet {
            
            if pageContollerSate != .None {
                if !subviews.contains(pageController) {
                    
                    pageController.numberOfPages = allImageUrls.count
                    addSubview(pageController)
                    bringSubviewToFront(pageController)
                }
            }
            
            switch pageContollerSate {
            case .None: break
            case .Left:
                pageController.snp_remakeConstraints(closure: { (make) in
                    make.left.equalTo(defalutPadding)
                    make.bottom.equalTo(0)
                })
                break
            case .Center:
                pageController.snp_remakeConstraints(closure: { (make) in
                    make.centerX.equalTo(0)
                    make.bottom.equalTo(0)
                })
                break
            case .Right: 
                pageController.snp_remakeConstraints(closure: { (make) in
                    make.right.equalTo(-defalutPadding)
                    make.bottom.equalTo(0)
                })
                break
            }
        }
    }
    
    
    private var animationTimer: NSTimer?
    private var needScroll = true
    private var currentArrayIndex: Int!
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var pageController: UIPageControl = UIPageControl()
    
    private lazy var previousDisplayView: UIImageView = {
        let previousDisplayView = UIImageView()
        previousDisplayView.userInteractionEnabled = true
        previousDisplayView.contentMode = .ScaleAspectFill
        return previousDisplayView
    }()
    
    private lazy var currentDisplayView: UIImageView = {
        let currentDisplayView = UIImageView()
        currentDisplayView.userInteractionEnabled = true
        currentDisplayView.contentMode = .ScaleAspectFill
        return currentDisplayView
    }()

    private lazy var lastDisplayView: UIImageView = {
        let lastDisplayView = UIImageView()
        lastDisplayView.userInteractionEnabled = true
        lastDisplayView.contentMode = .ScaleAspectFill
        return lastDisplayView
    }()
    
    //解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        if newSuperview == nil {
            cancelTimer()
        }
    }

    
    // MARK: - init mothod
    init(frame: CGRect, animationDuration: NSTimeInterval, inputImageUrls: [String]) {
        super.init(frame: frame)
        
        assert(inputImageUrls.count >= 1,"inputImageUrls can not be nil!")
        
        self.animationDuration = animationDuration
        currentArrayIndex = 1
        
        if inputImageUrls.count == 1 {
            needScroll = false
            self.currentArrayIndex = 0
        }
        
        allImageUrls = inputImageUrls

        addSubview(scrollView)
        scrollView.snp_makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        configScrollView(frame)
    }
    
    private func configScrollView(frame: CGRect) {
        scrollView.contentOffset = CGPointMake(CGRectGetWidth(frame), 0)
        
        scrollView.addSubview(previousDisplayView)
        scrollView.addSubview(currentDisplayView)
        scrollView.addSubview(lastDisplayView)
        
        previousDisplayView.snp_makeConstraints(closure: { (make) in
            make.left.top.bottom.equalTo(0)
            make.size.equalTo(scrollView.snp_size)
        })
        
        currentDisplayView.snp_makeConstraints(closure: { (make) in
            make.top.bottom.equalTo(0)
            make.size.equalTo(scrollView.snp_size)
            make.left.equalTo(previousDisplayView.snp_right)
        })
        
        lastDisplayView.snp_makeConstraints(closure: { (make) in
            make.top.right.bottom.equalTo(0)
            make.left.equalTo(currentDisplayView.snp_right)
            make.size.equalTo(scrollView.snp_size)
        })
        
        self.configDisplayViews()
        if needScroll {
            createScrollTimer()
        }
    }
    
    private func createScrollTimer() {
        cancelTimer()
        
        animationTimer = NSTimer.scheduledTimerWithTimeInterval(animationDuration, target: self, selector: Selector("timerFired"), userInfo: nil, repeats: true)
    }
    
    private func configDisplayViews() {
        let previousArrayIndex = getArrayIndex(currentArrayIndex - 1)
        let lastArrayIndex = getArrayIndex(currentArrayIndex + 1)
        configPreviousDisplayView(previousArrayIndex)
        configCurrentDisplayView()
        configLastDisplayView(lastArrayIndex)
    }
    
    private func getArrayIndex(currentIndex: Int) -> Int{
        if currentIndex == -1 {
            return allImageUrls.count - 1
        } else if currentIndex == allImageUrls.count {
            return 0
        } else {
            return currentIndex
        }
    }
    
    private func configPreviousDisplayView(previousArrayIndex: Int) {
        if allImageUrls[previousArrayIndex].hasPrefix("http"){
            previousDisplayView.kf_setImageWithURL(NSURL(string:allImageUrls[previousArrayIndex])!)
        } else {
            previousDisplayView.image = UIImage(named: allImageUrls[previousArrayIndex])
        }
    }
    
    private func configCurrentDisplayView() {
        if allImageUrls[currentArrayIndex].hasPrefix("http"){
            currentDisplayView.kf_setImageWithURL(NSURL(string:allImageUrls[currentArrayIndex])!)
        } else {
            currentDisplayView.image = UIImage(named: allImageUrls[currentArrayIndex])
        }
    }
    
    private func configLastDisplayView(lastArrayIndex: Int) {
        if allImageUrls[lastArrayIndex].hasPrefix("http"){
            lastDisplayView.kf_setImageWithURL(NSURL(string:allImageUrls[lastArrayIndex])!)
        } else {
            lastDisplayView.image = UIImage(named: allImageUrls[lastArrayIndex])
        }
    }
    
    // MARK: - Event
    @objc private func timerFired() {

        let newOffset = CGPointMake(scrollView.contentOffset.x + CGRectGetWidth(self.frame), scrollView.contentOffset.y)
        scrollView.setContentOffset(newOffset, animated: true)
    }
    
    private func cancelTimer() {
        if (animationTimer?.valid != nil) {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension DYHCycleScrollView: UIScrollViewDelegate {
    
    //MARK: - Scrollview delegate
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if autoScroll {
            cancelTimer()
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScroll {
            createScrollTimer()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(self.scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        
        if scrollView.contentOffset.x >= (2 * CGRectGetWidth(scrollView.frame)) {
            currentArrayIndex = getArrayIndex(currentArrayIndex + 1)
        } else if scrollView.contentOffset.x <= 0 {
            currentArrayIndex = getArrayIndex(currentArrayIndex - 1)
        }
        configDisplayViews()
        pageController.currentPage = currentArrayIndex
        scrollView.contentOffset = CGPointMake(CGRectGetWidth(scrollView.frame), 0)
    }
}
