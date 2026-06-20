package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Card;
import com.trannguyendiemhanh.auth.service.CardService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/cards")
public class CardController extends CrudController<Card, UUID> {
    public CardController(CardService service) {
        super(service);
    }
}
