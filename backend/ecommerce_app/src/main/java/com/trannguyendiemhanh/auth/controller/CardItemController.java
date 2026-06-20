package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.CardItem;
import com.trannguyendiemhanh.auth.service.CardItemService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/card-items")
public class CardItemController extends CrudController<CardItem, UUID> {
    public CardItemController(CardItemService service) {
        super(service);
    }
}
